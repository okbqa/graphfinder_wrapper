#!/usr/bin/env ruby
require 'sparql'

module GraphFinder; end unless defined? GraphFinder

class << GraphFinder
  # for OKBQA interface
  def okbqa_wrapper (template, disambiguation)
    raise ArgumentError, "Both template and disambiguation need to be supplied." if template.nil? || disambiguation.nil?
    disambiguation = disambiguation.first if disambiguation.is_a? Array

    slots = {}

    template["slots"].each do |s|
      if s["o"] == '<http://lodqa.org/vocabulary/sort_of>'
        slots[s["s"]] = {}
        slots[s["s"]]["type"] = 'rdf:Property'
        slots[s["s"]]["form"] = 'SORTAL'
      else
        p = s["p"]
        p = "form" if s["p"] == "verbalization"
        p = "type" if s["p"] == "is"

        slots[s["s"]] = {} if slots[s["s"]].nil?
        slots[s["s"]][p] = s["o"]
        slots[s["s"]]["disambig"] = []
      end
    end

    entities = []
    properties = []
    slots.each do |k, v|
      if v["type"] =~ /Property$/ then
        properties << k
      else
        entities << k
      end
    end

    # Index disambiguation results
    disambig_idx = {}

    disambiguation["entities"].each{|e| (disambig_idx[e["var"]] ||= []) << e}
    disambiguation["classes"].each{|c| (disambig_idx[c["var"]] ||= []) << c}
    disambiguation["properties"].each{|p| (disambig_idx[p["var"]] ||= []) << p}

    # get triples from template
    striples = []
    triples  = []

    query = template["query"].gsub(/ +/, ' ')
    sse = SPARQL.parse query
    sxp = SXP.read sse.to_sxp

    sxp_flat = sxp.flatten
    (0 .. sxp_flat.length - 2).each do |i|
      if sxp_flat[i] == :triple
        striples << sxp_flat[i+1 .. i+3].join(' ')
        triples  << {
          "subject" => sxp_flat[i+1].to_s.gsub!(/^\?/, ''),
          "predicate" => sxp_flat[i+2].to_s.gsub!(/^\?/, ''),
          "object" => sxp_flat[i+3].to_s.gsub!(/^\?/, '')
        }
      end
    end

    disambig_vals = disambig_idx.keys.sort.map{|v| disambig_idx[v]}
    disambig_sets = disambig_vals.first.product(*disambig_vals[1..-1])

    frame = query
    apgps = []
    disambig_sets.each do |disambig_set|
      disambig = disambig_set.inject({}){|h, d| h[d['var']] = d['value']; h}

      striples.each_with_index do |t, i|
        if i == 0
          frame.gsub!(/#{t.gsub(/\?/, '\?')} ?[.;]/, '_BGP_')
        else
          frame.gsub!(/#{t.gsub(/\?/, '\?')} ?[.;]/, '')
          frame.gsub!(/#{t.sub(/[^ .;]+ +/, '').gsub(/\?/, '\?')} ?[.;]/, '')
        end
      end
      frame.gsub!(/ +/, ' ')

      nodes = {}
      triples.each do |t|
        nodes[t["subject"]] = {}
        nodes[t["object"]] = {}
      end
      entities.each do |id|
        v = slots[id]
        nodes[id] = {"text" => v["form"], "term" => termify(disambig[id]), "type" => v["type"]}
      end

      relations = {}
      triples.each do |t|
        p = t["predicate"]
        relation = {"subject" => t["subject"], "object" => t["object"]}
        relation["text"] = slots[p]["form"] unless slots[p]["form"].nil?
        relation["type"] = slots[p]["type"] unless slots[p]["type"].nil?
        unless slots[p]["type"].nil?
          if slots[p]["value"] == 'SORTAL'
            relation["type"] = 'gf:Sortal'
          else
            relation["term"] = termify(disambig[p])
          end
        end
        relations[p] = relation
      end

      apgps << {"nodes" => nodes, "relations" => relations}
    end

    [apgps, frame]
  end

  def sparqlator(apgp, template)
    query = template
    slots = apgp["nodes"].merge(apgp["relations"])
    disambiguated = false
    slots.each{|v, s| if s["term"] then disambiguated = true; break end}

    if disambiguated
      slots.each do |v, s|
        unless slots[v].nil? || slots[v].empty?
          if slots[v]["term"]
            query.gsub!('?' + v, slots[v]["term"])
          elsif slots[v]["type"] && slots[v]["type"] == "gf:Sortal"
            query.gsub!('?' + v, 'a')
          end
        end
      end
      [{"query" => query, "score" => 0.8}]
    else
      []
    end
  end

  def termify (exp)
    if exp =~ /^https?:/
      "<#{exp}>"
    else
      exp
    end
  end

end