WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) as order_rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-11-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerMetrics AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        CASE WHEN COUNT(o.o_orderkey) = 0 THEN 'No Orders' 
        ELSE 'Has Orders' END AS order_status
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    coalesce(rd.o_orderkey, 0) AS order_id,
    cm.c_name AS customer_name,
    rd.o_orderdate AS order_date,
    rd.total_sales AS sales,
    sd.total_cost AS supplier_cost,
    cm.order_count,
    cm.total_spent,
    cm.order_status,
    RANK() OVER (ORDER BY rd.total_sales DESC) AS sales_rank
FROM 
    RankedOrders rd
FULL OUTER JOIN 
    CustomerMetrics cm ON rd.o_orderkey = cm.c_custkey
LEFT JOIN 
    SupplierDetails sd ON sd.total_cost = (
        SELECT 
            MAX(total_cost) 
        FROM 
            SupplierDetails
    )
WHERE 
    (cm.order_status = 'Has Orders' OR sd.total_cost IS NOT NULL)
ORDER BY 
    rd.total_sales DESC, cm.total_spent ASC;