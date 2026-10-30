WITH RegionSupplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_suppkey, s.s_name
),
CustomerOrder AS (
    SELECT 
        c.c_name AS customer_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_name
),
OrderLineItem AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
RankedSales AS (
    SELECT 
        RANK() OVER (PARTITION BY oli.total_line_items ORDER BY oli.net_sales DESC) AS sales_rank,
        oli.o_orderkey,
        oli.net_sales
    FROM 
        OrderLineItem oli
)
SELECT 
    rs.region_name,
    cs.customer_name,
    cs.total_order_value,
    rs.total_supply_cost,
    r.sales_rank
FROM 
    RegionSupplier rs
FULL OUTER JOIN 
    CustomerOrder cs ON rs.s_suppkey = cs.total_order_value
LEFT JOIN 
    RankedSales r ON r.o_orderkey = cs.total_order_value
WHERE 
    r.sales_rank IS NULL OR rs.total_supply_cost > 10000
ORDER BY 
    rs.region_name, cs.customer_name;