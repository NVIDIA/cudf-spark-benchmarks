WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT p.p_partkey) AS UniquePartsSupplied,
        AVG(s.s_acctbal) AS AverageAccountBalance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalOrderValue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey
),
ProjectedOrderValues AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS ProjectedRevenues
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ns.n_name AS NationName,
    SUM(ss.TotalSupplyCost) AS TotalSupplierCost,
    AVG(co.TotalOrderValue) AS AvgCustomerOrderValue,
    SUM(pv.ProjectedRevenues) AS TotalProjectedRevenues
FROM 
    nation ns
JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
JOIN 
    CustomerOrders co ON co.c_custkey = s.s_suppkey
JOIN 
    ProjectedOrderValues pv ON pv.o_orderkey = co.TotalOrders
GROUP BY 
    ns.n_name
ORDER BY 
    TotalProjectedRevenues DESC
LIMIT 10;