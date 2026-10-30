
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn,
        s.s_nationkey
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrders c
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue_after_discount,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    t.n_name AS Supplier_Nation,
    t.s_name AS Supplier_Name,
    tc.c_name AS Customer_Name,
    ol.revenue_after_discount AS Revenue,
    ol.o_orderdate AS Order_Date,
    COUNT(ol.l_orderkey) OVER (PARTITION BY t.s_suppkey) AS Order_Count,
    AVG(ol.revenue_after_discount) OVER (PARTITION BY t.s_suppkey) AS Avg_Revenue
FROM 
    TopSuppliers t
JOIN 
    partsupp ps ON t.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    OrderLineDetails ol ON l.l_orderkey = ol.l_orderkey
JOIN 
    TopCustomers tc ON ol.o_orderstatus = 'F'
WHERE 
    t.s_acctbal IS NOT NULL
    AND ol.o_orderdate >= DATE '1997-01-01'
ORDER BY 
    Supplier_Nation, Revenue DESC;
