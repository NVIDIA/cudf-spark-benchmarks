
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS customer_total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(cs.customer_total_spent) AS avg_customer_spent,
    MAX(ss.total_avail_qty) AS max_avail_qty,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_total_price,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 100 THEN 'High Volume'
        WHEN COUNT(DISTINCT o.o_orderkey) BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume' 
    END AS order_volume_category
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrderStats cs ON cs.c_custkey = o.o_custkey
LEFT JOIN 
    SupplierParts ss ON ss.ps_partkey = l.l_partkey AND ss.ps_suppkey = s.s_suppkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
