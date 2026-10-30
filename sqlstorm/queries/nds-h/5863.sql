WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.c_nationkey,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_retailprice,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name, s.s_acctbal, p.p_retailprice
),
FinalReport AS (
    SELECT 
        t.o_orderkey,
        t.o_orderdate,
        t.c_nationkey,
        s.s_name,
        s.total_quantity,
        ROUND(s.p_retailprice * s.total_quantity, 2) AS total_cost
    FROM 
        TopRevenueOrders t
    JOIN 
        SupplierDetails s ON t.o_orderkey = s.ps_partkey
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.c_nationkey,
    f.s_name,
    CASE 
        WHEN f.total_cost > 10000 THEN 'High Value'
        WHEN f.total_cost > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category,
    SUM(f.total_cost) OVER (PARTITION BY f.o_orderkey) AS cumulative_order_cost
FROM 
    FinalReport f
ORDER BY 
    f.o_orderdate DESC, f.c_nationkey, order_value_category;
