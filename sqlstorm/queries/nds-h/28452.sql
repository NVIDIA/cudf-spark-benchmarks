
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 1000
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.s_acctbal
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 3
)
SELECT 
    ts.region_name,
    ts.nation_name,
    STRING_AGG(ts.supplier_name || ' (' || CAST(ts.s_acctbal AS STRING) || ')', ', ') AS supplier_list
FROM TopSuppliers ts
GROUP BY ts.region_name, ts.nation_name
ORDER BY ts.region_name, ts.nation_name;
