WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(o.order_count, 0) AS order_count,
        COALESCE(o.total_spent, 0) AS total_spent,
        CASE 
            WHEN COALESCE(o.total_spent, 0) > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_segment
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders o ON c.c_custkey = o.c_custkey
),
SupplyAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        r.r_name AS region_name,
        SUM(CASE WHEN l.l_quantity < 10 THEN l.l_extendedprice * (1 - l.l_discount) END) AS low_quantity_revenue,
        AVG(l.l_discount) AS average_discount
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, r.r_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.order_count,
    c.total_spent,
    s.supplier_rank,
    s.total_supply_value,
    sa.p_partkey,
    sa.p_name,
    sa.p_retailprice,
    sa.region_name,
    sa.low_quantity_revenue,
    sa.average_discount,
    CASE 
        WHEN sa.low_quantity_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    HighValueCustomers c
FULL OUTER JOIN 
RankedSuppliers s ON c.c_custkey = s.s_suppkey
LEFT JOIN 
    SupplyAnalysis sa ON s.s_suppkey = sa.p_partkey
WHERE 
    (c.total_spent > 5000 OR s.total_supply_value < 10000)
    AND (c.customer_segment = 'High Value' OR sa.average_discount > 0.15)
ORDER BY 
    COALESCE(c.total_spent, 0) DESC, 
    s.total_supply_value ASC
LIMIT 50;
