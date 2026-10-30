WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
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
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerTotals AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RegionPerformance AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_sales,
        AVG(ct.total_orders) AS avg_customer_order
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        CustomerTotals ct ON c.c_custkey = ct.c_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    rp.r_name,
    rp.customer_count,
    rp.total_sales,
    rp.avg_customer_order,
    sd.total_supply_cost,
    DENSE_RANK() OVER (ORDER BY rp.total_sales DESC) AS sales_rank
FROM 
    RegionPerformance rp
LEFT JOIN 
    SupplierDetails sd ON sd.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
WHERE 
    rp.total_sales IS NOT NULL 
ORDER BY 
    rp.total_sales DESC, 
    rp.r_name ASC;