#!/usr/bin/env ruby
require 'sparql'

module GraphFinder; end unless defined? GraphFinder

class << GraphFinder
  # for OKBQA interface
  def okbqa_wrapper (template, disambiguation)
    raise ArgumentError, "Both template and disambiguation need to be supplied." if template.nil? || disambiguation.nil?

    slots = {}

    template[:slots].each do |s|
      p = s[:p].to_sym
      p = :form if s[:p] == "verbalization"
      p = :annotation if s[:p] == "is"

      slots[s[:s]] = {} if slots[s[:s]].nil?
      slots[s[:s]][p] = s[:o]
    end

    entities   = slots.select{|s| s["annotation"] !~ /Property$/}.keys
    properties = slots.select{|s| s["annotation"] =~ /Property$/}.keys

    disambiguation[:entities].each{|e| slots[e[:var]].merge!(e)}
    disambiguation[:classes].each{|c| slots[c[:var]].merge!(c)}
    disambiguation[:properties].each{|p| slots[p[:var]].merge!(p)}

    striples = []
    triples  = []

    query = template[:query].gsub(/ +/, ' ')
    sse = SPARQL.parse query
    sxp = SXP.read sse.to_sxp
    sxp_flat = sxp.flatten
    (0 .. sxp_flat.length - 2).each do |i|
      if sxp_flat[i] == :triple
        striples << sxp_flat[i+1 .. i+3].join(' ')
        triples  << {
          subject:sxp_flat[i+1].to_s.gsub!(/^\?/, ''),
          predicate:sxp_flat[i+2].to_s.gsub!(/^\?/, ''),
          object:sxp_flat[i+3].to_s.gsub!(/^\?/, '')
        }
      end
    end

    frame = query
    striples.each_with_index do |t, i|
      if i == 0
        frame.gsub!(/#{t.gsub(/\?/, '\?')} ?\./, '_BGP_')
      else
        frame.gsub!(/#{t.gsub(/\?/, '\?')} ?\./, '')
      end
    end

    nodes = {}
    triples.each do |t|
      nodes[t[:subject]] = {}
      nodes[t[:object]] = {}
    end
    entities.each do |id|
      v = slots[id]
      nodes[id] = {text:v[:form], term:"<#{v[:value]}>", annotation:v[:annotation]}
    end

    edges = triples.map do |t|
      p = t[:predicate]
      edge = {subject:t[:subject], object:t[:object], text:slots[p][:form], annotation:slots[p][:annotation]}
      edge[:term] = slots[p][:value]
      edge
    end

    [{nodes:nodes, edges:edges}, frame]
  end
end