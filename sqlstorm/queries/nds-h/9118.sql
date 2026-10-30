WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 5
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name 
    FROM 
        RankedSuppliers s
    WHERE 
        s.Rank <= 10
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        SUM(l.l_quantity) AS TotalQuantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
SupplierOrderSummary AS (
    SELECT 
        ts.s_suppkey, 
        ts.s_name, 
        COUNT(od.o_orderkey) AS NumberOfOrders,
        SUM(od.TotalRevenue) AS TotalRevenueFromOrders
    FROM 
        TopSuppliers ts
    JOIN 
        partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        OrderDetails od ON l.l_orderkey = od.o_orderkey
    GROUP BY 
        ts.s_suppkey, ts.s_name
) 
SELECT 
    s.s_suppkey, 
    s.s_name, 
    sos.NumberOfOrders, 
    sos.TotalRevenueFromOrders
FROM 
    SupplierOrderSummary sos
JOIN 
    TopSuppliers s ON sos.s_suppkey = s.s_suppkey
WHERE 
    sos.TotalRevenueFromOrders > 50000
ORDER BY 
    sos.TotalRevenueFromOrders DESC;