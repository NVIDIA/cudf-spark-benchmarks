
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_brand
),
CriticalOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_sales
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, 
        o.o_totalprice
)
SELECT 
    r.r_name,
    r.r_comment,
    COALESCE(SUM(rp.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(SUM(co.net_sales), 0) AS total_net_sales,
    COUNT(DISTINCT co.o_orderkey) AS total_orders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedParts rp ON s.s_suppkey = rp.p_partkey
LEFT JOIN 
    CriticalOrders co ON co.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_acctbal > 10000
        )
    )
WHERE 
    r.r_name IS NOT NULL 
GROUP BY 
    r.r_name, 
    r.r_comment
HAVING 
    COUNT(DISTINCT co.o_orderkey) > 0
ORDER BY 
    total_net_sales DESC
LIMIT 10;
