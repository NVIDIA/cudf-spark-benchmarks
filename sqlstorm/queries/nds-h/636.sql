WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
LineitemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS item_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(ss.supplier_count, 0) AS supplier_count,
    AVG(ls.net_revenue) AS average_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS order_count
FROM 
    part p
LEFT JOIN 
    SupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    LineitemSummary ls ON l.l_orderkey = ls.l_orderkey
LEFT JOIN 
    RankedOrders ro ON ls.l_orderkey = ro.o_orderkey AND ro.price_rank <= 10
WHERE 
    p.p_size BETWEEN 5 AND 20 
    AND (p.p_container = 'BOX' OR p.p_container = 'BAG')
GROUP BY 
    p.p_partkey, p.p_name, ss.total_supply_cost, ss.supplier_count
HAVING 
    AVG(ls.net_revenue) > 5000
ORDER BY 
    order_count DESC, total_supply_cost DESC;