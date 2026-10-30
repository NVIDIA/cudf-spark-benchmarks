WITH  OrderCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS row_num
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierCTE AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY s.total_supply_cost DESC) AS rank
    FROM 
        SupplierCTE s
    WHERE 
        s.total_supply_cost > 10000
),
RegionSales AS (
    SELECT 
        n.n_regionkey, 
        r.r_name,
        SUM(o.total_sales) AS region_sales
    FROM 
        OrderCTE o
    JOIN 
        customer c ON o.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
)

SELECT 
    r.r_name,
    COALESCE(rs.region_sales, 0) AS region_sales,
    COALESCE(ts.total_supply_cost, 0) AS supplier_cost,
    CASE 
        WHEN rs.region_sales > ts.total_supply_cost THEN 'Sales Exceeded'
        ELSE 'Cost Exceeded'
    END AS SalesVsCost
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = 1
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    region_sales DESC, supplier_cost DESC;
