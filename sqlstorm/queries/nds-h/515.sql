
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        cs.total_orders,
        cs.max_order_value
    FROM 
        CustomerSummary cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.max_order_value > 1000
),
SupplierCustomerOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        hc.c_custkey,
        hc.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        SupplierDetails s
    LEFT JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        HighValueCustomers hc ON o.o_custkey = hc.c_custkey
    GROUP BY 
        s.s_suppkey, s.s_name, hc.c_custkey, hc.c_name
)
SELECT 
    s.s_name,
    COUNT(DISTINCT so.order_count) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    SupplierCustomerOrders so
JOIN 
    lineitem l ON so.s_suppkey = l.l_suppkey
LEFT JOIN 
    supplier s ON so.s_suppkey = s.s_suppkey
WHERE 
    l.l_shipdate >= '1997-01-01'
GROUP BY 
    s.s_name
HAVING 
    COUNT(DISTINCT so.order_count) > 5
ORDER BY 
    total_revenue DESC;
