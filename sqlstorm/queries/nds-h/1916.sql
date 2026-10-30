WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL 
        AND c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(co.order_count, 0) AS total_orders,
        COALESCE(co.avg_order_value, 0) AS avg_order_value,
        RANK() OVER (ORDER BY COALESCE(co.avg_order_value, 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT 
    r.region_name,
    rc.c_name,
    rc.total_orders,
    rc.avg_order_value
FROM 
    RegionalSales r
JOIN 
    RankedCustomers rc ON r.unique_customers = rc.total_orders
WHERE 
    rc.rank <= 10
ORDER BY 
    r.total_sales DESC, rc.avg_order_value DESC;