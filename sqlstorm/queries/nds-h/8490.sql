WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        AVG(c.c_acctbal) AS avg_customer_balance,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierSummary AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
),
FinalMetrics AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        os.unique_customers,
        os.avg_customer_balance,
        ss.total_supply_value,
        ss.total_parts_supplied,
        os.last_ship_date
    FROM 
        OrderSummary os
    JOIN 
        SupplierSummary ss ON os.o_orderkey % 10 = ss.ps_suppkey % 10  
)
SELECT 
    f.o_orderkey,
    f.total_revenue,
    f.unique_customers,
    f.avg_customer_balance,
    f.total_supply_value,
    f.total_parts_supplied,
    f.last_ship_date
FROM 
    FinalMetrics f
ORDER BY 
    f.total_revenue DESC
LIMIT 10;