from rdflib import Graph, URIRef
from rdflib.namespace import SKOS

root_concept = "http://thesauri.dainst.org/_fe65f286"
concept_counter = 0

def accumulate_graph(url, depths):
  global concept_counter

  concept_counter += 1

  print(f'found {url} at hierarchy depths of {depths}.')

  g = Graph()
  g.parse(url)

  for s, p, o in g.triples((None, SKOS.narrower, None)):
    narrower_url = o.toPython() + ".ttl"
    g += accumulate_graph(narrower_url, depths + 1)

  return g

graph = accumulate_graph(f"{root_concept}.ttl", 0)

print(f"writing final graph containing {concept_counter} concepts")

graph.serialize(destination="thesauri.ttl")