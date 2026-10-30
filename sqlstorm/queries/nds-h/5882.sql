WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        sc.total_supply_cost
    FROM 
        part p
    JOIN 
        SupplierCost sc ON p.p_partkey = sc.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COUNT(DISTINCT h.p_partkey) AS part_count,
    SUM(h.p_retailprice) AS total_retail_value
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueParts h ON l.l_partkey = h.p_partkey
WHERE 
    r.order_rank <= 100
GROUP BY 
    r.o_orderkey, r.o_orderdate, r.o_totalprice
ORDER BY 
    r.o_orderdate DESC, total_retail_value DESC
LIMIT 50;