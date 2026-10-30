WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierPerformance AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_suppkey
),
CustomerPerformance AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'Retail'
    GROUP BY 
        c.c_custkey
)
SELECT 
    os.o_orderkey,
    os.total_revenue,
    sp.total_cost AS supplier_cost,
    cp.total_spent AS customer_spending,
    os.unique_customers,
    os.unique_suppliers
FROM 
    OrderSummary os
JOIN 
    SupplierPerformance sp ON sp.supplied_parts > 5
JOIN 
    CustomerPerformance cp ON cp.orders_count > 10
ORDER BY 
    os.total_revenue DESC
LIMIT 50;