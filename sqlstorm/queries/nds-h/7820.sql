
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
FrequentlyOrderedParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_sales
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(l.l_quantity) > 100
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.o_totalprice) AS total_order_value,
    COUNT(DISTINCT f.ps_partkey) AS unique_ordered_parts,
    AVG(f.total_quantity) AS avg_quantity_ordered,
    AVG(f.total_sales) AS avg_sales_per_part
FROM 
    TopRegions tr
JOIN 
    orders o ON tr.total_revenue = o.o_totalprice
JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
JOIN 
    FrequentlyOrderedParts f ON f.ps_partkey = ro.o_orderkey
JOIN 
    nation n ON o.o_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_order_value DESC;
