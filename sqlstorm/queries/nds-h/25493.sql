WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationSupplier AS (
    SELECT nd.n_name AS nation_name, COUNT(sd.s_suppkey) AS supplier_count, SUM(sd.part_count) AS total_parts
    FROM SupplierDetails sd
    JOIN nation nd ON sd.s_nationkey = nd.n_nationkey
    GROUP BY nd.n_name
),
HighPartNations AS (
    SELECT ns.nation_name, ns.supplier_count, ns.total_parts
    FROM NationSupplier ns
    WHERE ns.total_parts > (SELECT AVG(total_parts) FROM NationSupplier)
)
SELECT np.nation_name, np.supplier_count, np.total_parts,
       CONCAT(np.nation_name, ' has ', np.supplier_count, ' suppliers providing ', np.total_parts, ' parts.') AS detailed_info
FROM HighPartNations np
ORDER BY np.total_parts DESC;
