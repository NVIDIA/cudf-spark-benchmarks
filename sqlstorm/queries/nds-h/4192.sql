WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS orders_placed,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders
)
SELECT 
    p.p_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ss.supplier_count, 0) AS supplier_count,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    rc.c_name AS top_customer,
    rc.total_spent AS top_customer_spent
FROM 
    part p
LEFT JOIN 
    TotalSales ts ON p.p_partkey = ts.p_partkey
LEFT JOIN 
    SupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    RankedCustomers rc ON rc.customer_rank = 1
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
    AND p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
ORDER BY 
    total_sales DESC NULLS LAST, 
    p.p_name ASC;
