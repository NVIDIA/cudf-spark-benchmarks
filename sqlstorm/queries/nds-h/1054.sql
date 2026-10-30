WITH CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighVolumeCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 10000
),
TopSuppliers AS (
    SELECT 
        spi.s_suppkey,
        spi.s_name,
        spi.part_count,
        SPI.avg_supply_cost,
        RANK() OVER (ORDER BY spi.part_count DESC) AS supplier_rank
    FROM 
        SupplierPartInfo spi
    WHERE 
        spi.avg_supply_cost < 50.00
)

SELECT 
    hvc.c_name AS customer_name, 
    hvc.total_sales AS customer_total_sales,
    ts.s_name AS supplier_name, 
    ts.part_count AS total_parts_supplied
FROM 
    HighVolumeCustomers hvc
    LEFT JOIN TopSuppliers ts ON hvc.order_count > ts.part_count
ORDER BY 
    hvc.sales_rank, ts.supplier_rank;
