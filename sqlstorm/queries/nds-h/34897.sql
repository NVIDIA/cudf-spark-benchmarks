WITH  OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        SUM(l.l_extendedprice) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    os.o_orderkey,
    os.total_sales,
    ts.s_name,
    ts.total_supply_cost
FROM 
    OrderSummary os
LEFT JOIN 
    TopSuppliers ts ON os.o_orderkey = ts.s_suppkey
WHERE 
    ts.rank <= 5 
    OR os.total_sales > (SELECT AVG(total_sales) FROM OrderSummary)
ORDER BY 
    os.total_sales DESC, ts.total_supply_cost ASC;