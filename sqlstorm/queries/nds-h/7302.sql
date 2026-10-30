
WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(pc.total_sales) AS total_sales_last_6_months,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(sc.total_cost) AS supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
JOIN 
    ProductDetails pc ON l.l_partkey = pc.p_partkey
JOIN 
    RecentOrders ro ON l.l_orderkey = ro.o_orderkey
WHERE 
    sc.total_cost > 10000
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_sales_last_6_months DESC;
