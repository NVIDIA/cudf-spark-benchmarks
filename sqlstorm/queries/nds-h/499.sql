WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal > 10000 THEN 'High'
            WHEN s.s_acctbal BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS acctbal_category
    FROM 
        supplier s
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= (cast('1998-10-01' as date) - INTERVAL '1 year') 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    ps.ps_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ss.s_name,
    ss.acctbal_category,
    COALESCE(os.total_orders, 0) AS total_orders_by_customer,
    COALESCE(os.total_spent, 0) AS total_spent_by_customer,
    l.total_line_value
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierStats ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderSummary os ON ss.s_suppkey = os.o_custkey
LEFT JOIN 
    LineItemDetails l ON l.l_partkey = rp.p_partkey
ORDER BY 
    rp.p_retailprice DESC, 
    ss.acctbal_category, 
    total_line_value DESC
LIMIT 100;