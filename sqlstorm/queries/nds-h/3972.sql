WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    cn.n_name AS nation_name,
    r.r_name AS region_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(spi.avg_supply_cost) AS average_supply_cost
FROM 
    customer c
LEFT JOIN 
    nation cn ON c.c_nationkey = cn.n_nationkey
LEFT JOIN 
    region r ON cn.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierPartInfo spi ON li.l_partkey = spi.ps_partkey AND li.l_suppkey = spi.s_suppkey
WHERE 
    o.o_orderstatus = 'O' 
    AND li.l_shipdate <= cast('1998-10-01' as date) 
    AND (c.c_acctbal IS NOT NULL AND c.c_acctbal > 0)
GROUP BY 
    cn.n_name, r.r_name, c.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    total_revenue DESC
LIMIT 100;