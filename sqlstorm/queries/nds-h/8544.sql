
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        CTE1.r_part_count,
        CTE1.r_total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rnk,
        o.o_custkey  -- Added to GROUP BY later
    FROM 
        orders o
    JOIN (
        SELECT
            l.l_orderkey,
            COUNT(DISTINCT l.l_partkey) as r_part_count,
            SUM(l.l_extendedprice) as r_total_price
        FROM 
            lineitem l
        GROUP BY 
            l.l_orderkey
    ) AS CTE1 ON o.o_orderkey = CTE1.l_orderkey
)
SELECT 
    national.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT cust.c_custkey) AS customer_count,
    AVG(ranked.r_total_price) AS avg_order_value,
    SUM(ranked.r_part_count) AS total_parts_ordered
FROM 
    RankedOrders ranked
JOIN 
    customer cust ON ranked.o_custkey = cust.c_custkey
JOIN 
    nation national ON cust.c_nationkey = national.n_nationkey
JOIN 
    region r ON national.n_regionkey = r.r_regionkey
WHERE 
    ranked.rnk <= 10
GROUP BY 
    national.n_name, r.r_name, ranked.o_custkey  -- Added o_custkey to GROUP BY
ORDER BY 
    customer_count DESC, avg_order_value DESC;
