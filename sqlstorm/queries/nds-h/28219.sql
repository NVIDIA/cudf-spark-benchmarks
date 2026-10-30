WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
JoinedData AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_type,
        si.s_name AS supplier_name,
        si.nation_name,
        si.region_name,
        si.comment_length,
        ps.total_availqty,
        ps.total_supplycost
    FROM part p
    JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
    JOIN SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
)
SELECT 
    COUNT(DISTINCT j.p_partkey) AS unique_parts_count,
    AVG(j.comment_length) AS average_comment_length,
    SUM(j.total_availqty) AS total_availability,
    SUM(j.total_supplycost) AS total_cost
FROM JoinedData j
WHERE j.region_name = 'NORTH AMERICA'
  AND j.total_availqty > 100
  AND j.supplier_name LIKE '%Supplier%'
GROUP BY j.region_name
HAVING AVG(j.total_supplycost) > 500.00;
