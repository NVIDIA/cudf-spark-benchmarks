WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), TopMonthlyOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.c_name
    FROM 
        RankedOrders o
    WHERE 
        o.rnk <= 5
), SupplierSummary AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
), HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_cost,
        ss.unique_parts
    FROM 
        supplier s
    JOIN 
        SupplierSummary ss ON s.s_suppkey = ss.ps_suppkey
    WHERE 
        ss.total_cost > (
            SELECT AVG(total_cost) FROM SupplierSummary
        )
), CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    mo.o_orderkey,
    mo.o_orderdate,
    mo.o_totalprice,
    mo.c_name AS customer_name,
    hs.s_name AS supplier_name,
    cs.order_count,
    cs.total_spent
FROM 
    TopMonthlyOrders mo
JOIN 
    lineitem l ON mo.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    HighValueSuppliers hs ON ps.ps_suppkey = hs.s_suppkey
JOIN 
    CustomerOrderStats cs ON mo.c_name = cs.c_name
ORDER BY 
    mo.o_orderdate DESC, mo.o_totalprice DESC;
