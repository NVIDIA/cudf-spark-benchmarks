
WITH RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        r.c_custkey, 
        r.c_name 
    FROM 
        RankedSales r 
    WHERE 
        r.rn <= 5
),
SalesAndSupply AS (
    SELECT 
        tc.c_custkey,
        tc.c_name,
        ss.total_supply_cost,
        rs.total_sales
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SupplierInfo ss ON tc.c_custkey = ss.s_suppkey  
    JOIN 
        RankedSales rs ON tc.c_custkey = rs.c_custkey
)
SELECT 
    s.c_custkey,
    s.c_name,
    s.total_sales,
    s.total_supply_cost,
    CASE 
        WHEN s.total_sales > s.total_supply_cost THEN 'Sales Exceeds Supply Cost'
        WHEN s.total_sales < s.total_supply_cost THEN 'Supply Cost Exceeds Sales'
        ELSE 'Sales and Supply Cost Equal'
    END AS comparison
FROM 
    SalesAndSupply s
WHERE 
    s.total_supply_cost IS NOT NULL
ORDER BY 
    s.total_sales DESC, 
    s.total_supply_cost ASC;
