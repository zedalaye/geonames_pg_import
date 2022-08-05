drop function if exists Get_Hierarchy;
drop function if exists Get_Hierarchy_With_Parent;

-- composite type, wraps a geoname row with a parent_id and a level
drop type if exists geoname_with_parent;
create type geoname_with_parent as (g geoname, parent_id integer, level integer);

-- returns the geoname_with_parent type
create or replace function Get_Hierarchy_With_Parent(geonameid integer, level integer default 0)
returns setof geoname_with_parent
language plpgsql as
$$
declare
  r geoname_with_parent;
begin
  for r in (select (g.*)::geoname, h.parent_id, level
            from geoname g
            left outer join hierarchy h on (h.child_id = g.id and h.type = 'ADM')
            where g.id = geonameid)
  loop
    return query select * from Get_Hierarchy_With_Parent(r.parent_id, r.level + 1);
    return next r;
  end loop;

  return;
end;
$$;

-- returns the geoname type
create or replace function Get_Hierarchy(geonameid integer, level integer default 0)
returns setof geoname
language plpgsql as
$$
declare
  r geoname_with_parent;
begin
  for r in (select (g.*)::geoname, h.parent_id, level
            from geoname g
            left outer join hierarchy h on (h.child_id = g.id and h.type = 'ADM')
            where g.id = geonameid)
  loop
    return query select * from Get_Hierarchy(r.parent_id, r.level + 1);
    return next r.g;
  end loop;

  return;
end;
$$;

/* how to call these functions */
-- select level, parent_id, (g).* from get_hierarchy_with_parent(2988507);
-- select * from get_hierarchy(2988507);