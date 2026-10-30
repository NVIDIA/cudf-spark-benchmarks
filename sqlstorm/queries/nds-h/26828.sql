
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CONCAT('Supplier: ', s.s_name, ' | Balance: ', CAST(s.s_acctbal AS DECIMAL(10, 2)), ' | Nation: ', n.n_name) AS SupplierInfo,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.SupplierInfo,
        s.TotalSupplyValue,
        ROW_NUMBER() OVER (ORDER BY s.TotalSupplyValue DESC) AS Rank
    FROM 
        SupplierDetails s
    WHERE 
        s.TotalSupplyValue > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        od.SupplierInfo,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        HighValueSuppliers od ON l.l_suppkey = od.s_suppkey
    GROUP BY 
        o.o_orderkey, od.SupplierInfo
)
SELECT 
    od.o_orderkey,
    od.SupplierInfo,
    od.TotalOrderValue,
    CASE 
        WHEN od.TotalOrderValue > 50000 THEN 'High Value Order'
        WHEN od.TotalOrderValue BETWEEN 20000 AND 50000 THEN 'Medium Value Order'
        ELSE 'Low Value Order' 
    END AS OrderValueCategory
FROM 
    OrderDetails od
WHERE 
    od.TotalOrderValue IS NOT NULL
ORDER BY 
    od.TotalOrderValue DESC;
