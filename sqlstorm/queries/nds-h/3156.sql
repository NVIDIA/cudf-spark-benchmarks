WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    AVG(CASE WHEN lo.o_totalprice IS NOT NULL THEN lo.o_totalprice ELSE 0 END) AS avg_order_price
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders lo ON l.l_orderkey = lo.o_orderkey AND lo.order_rank <= 10
LEFT JOIN 
    SupplierPartStats ps ON p.p_partkey = ps.ps_partkey
WHERE 
    p.p_size BETWEEN 10 AND 50
    AND p.p_type LIKE '%BRASS%'
    AND ps.total_avail_qty IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 100;
