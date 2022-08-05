-- Recursive CTE to get up levels herarchy from a geoname record
with recursive
    ancestors as (
      select g.*, h.parent_id, h.type
      from geoname_light_fr g
      join hierarchy h on (h.child_id = g.id)
      where g.search_vector @@ to_tsquery('french', 'paris')

      union all

      select g.*, h.parent_id, h.type
      from geoname_light_fr g
      left outer join hierarchy h on (h.child_id = g.id)
      join ancestors a on (a.parent_id = g.id)
    )
select id, parent_id, type, preferred_name, name, feature_class, feature_code
from ancestors;

-- Same query, factored for better readability (same performance)
with recursive
  tree as (
    select g.*, h.parent_id, h.type
    from geoname_light_fr g
    join hierarchy h on (h.child_id = g.id)
  ),

  starting as (
    select t.*
    from tree t
    where t.search_vector @@ to_tsquery('french', 'paris')
  ),

  ancestors as (
    select s.*
    from starting s

    union all

    select g.*, h.parent_id, h.type
    from geoname_light_fr g
    left outer join hierarchy h on (h.child_id = g.id)
    join ancestors a on (a.parent_id = g.id)
  )
select id, parent_id, type, preferred_name, name, feature_class, feature_code
from ancestors;