WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, p.p_name AS part_name, 
           ps.ps_availqty, ps.ps_supplycost, ps.ps_comment, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT * 
    FROM SupplierDetails 
    WHERE rank <= 5
)
SELECT nation_name, STRING_AGG(part_name, ', ') AS part_names, 
       STRING_AGG(CAST(ps_supplycost AS STRING), ', ') AS supply_costs, 
       STRING_AGG(ps_comment, '; ') AS comments
FROM TopSuppliers
GROUP BY nation_name
ORDER BY nation_name;
