WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_spent
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
), 

CustomerDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
), 

SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COUNT(DISTINCT(ps.ps_partkey)) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)

SELECT 
    cd.c_name,
    cd.total_quantity,
    cd.order_count,
    so.o_orderkey AS latest_order,
    so.o_orderdate,
    spd.s_name AS supplier_name,
    spd.unique_parts_supplied,
    CASE 
        WHEN cd.order_count > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS customer_status
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedOrders so ON cd.c_custkey = so.o_custkey AND so.order_rank = 1
LEFT JOIN 
    SupplierPartDetails spd ON spd.unique_parts_supplied > 5
WHERE 
    cd.total_quantity IS NOT NULL
    AND (cd.total_quantity != 0 OR cd.order_count IS NULL)
ORDER BY 
    cd.total_quantity DESC NULLS LAST,
    supplier_name ASC
LIMIT 100;
