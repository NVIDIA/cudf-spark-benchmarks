WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice > (SELECT AVG(o_totalprice) * 0.75 FROM orders)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(CASE 
            WHEN ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp) THEN ps.ps_availqty 
            ELSE 0 
        END) AS total_available_below_avg_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    SUM(CASE 
            WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) 
            ELSE 0 
        END) AS total_returned_value,
    AVG(sd.total_parts) AS average_parts_per_supplier,
    MAX(sd.total_available_below_avg_cost) AS max_available_below_avg_cost
FROM 
    lineitem li
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
JOIN 
    SupplierDetails sd ON sd.s_suppkey = s.s_suppkey
WHERE 
    r.r_name IS NOT NULL
    AND n.n_name IS NOT NULL
    AND p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY 
    r.r_name, n.n_name, p.p_name
HAVING 
    SUM(CASE 
            WHEN li.l_linestatus = 'O' THEN 1 
            WHEN li.l_linestatus = 'F' THEN 1
            ELSE 0 
        END) > 5
ORDER BY 
    r.r_name, n.n_name, total_returned_value DESC NULLS LAST;
