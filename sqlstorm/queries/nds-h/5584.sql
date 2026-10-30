
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey, n.n_name
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name
),
AggregatedData AS (
    SELECT 
        rs.nation_name,
        COUNT(DISTINCT co.c_custkey) AS unique_customers,
        SUM(co.total_order_value) AS total_sales_value,
        AVG(co.order_count) AS avg_orders_per_customer
    FROM 
        RankedSuppliers rs
    JOIN 
        CustomerOrders co ON rs.rank = 1
    GROUP BY 
        rs.nation_name
)
SELECT 
    nation_name,
    unique_customers,
    total_sales_value,
    avg_orders_per_customer
FROM 
    AggregatedData
WHERE 
    unique_customers > 10 AND total_sales_value > 50000
ORDER BY 
    total_sales_value DESC;
