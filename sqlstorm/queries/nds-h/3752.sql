
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IS NULL OR o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size < 25
)
SELECT 
    css.c_name,
    ss.s_name,
    ps.p_name,
    ps.p_retailprice,
    css.total_spent,
    sps.total_value,
    COALESCE(ps.p_retailprice - (sps.total_value / NULLIF(sps.total_parts, 0)), 0) AS adjusted_price
FROM 
    CustomerOrders css
JOIN 
    SupplierStats sps ON css.order_count > 5
JOIN 
    lineitem l ON css.c_custkey = l.l_orderkey 
JOIN 
    PartDetails ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    supplier ss ON l.l_suppkey = ss.s_suppkey
WHERE 
    ps.price_rank <= 3
ORDER BY 
    css.total_spent DESC, sps.total_value DESC;
