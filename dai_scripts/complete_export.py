import argparse
import sys

from rdflib import Graph
from rdflib.namespace import SKOS
from rdflib.util import SUFFIX_FORMAT_MAP

concept_counter = 0

root_concept = "http://thesauri.dainst.org/_fe65f286"

format_suffix_mapping = {
    'turtle': 'ttl',
    'xml': 'xml',
    'json-ld': 'json'
}

def accumulate_graph(url, depths):
  global concept_counter
  print(f'found {url} at hierarchy depths of {depths}.')

  g = Graph()
  g.parse(url)

  concept_counter += 1

  for s, p, o in g.triples((None, SKOS.narrower, None)):
    narrower_url = o.toPython() + ".ttl"
    g += accumulate_graph(narrower_url, depths + 1)

  return g

parser = argparse.ArgumentParser(description='Exports the full iDAI.world concept tree.')
parser.add_argument('format', type=str, choices=format_suffix_mapping.keys(), help=f"Specify a output format.")

args = parser.parse_args()

graph = accumulate_graph(f"{root_concept}.ttl", 0)

print(f"writing final graph containing {concept_counter} concepts")

graph.serialize(destination=f"thesauri.{format_suffix_mapping[args.format]}", format=args.format)