WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
CustomerPriorities AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING' OR o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
Report AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        ss.total_avail_qty,
        ss.avg_acctbal,
        os.line_item_count,
        os.total_revenue,
        cp.order_count,
        cp.total_spent,
        CASE 
            WHEN cp.total_spent IS NULL THEN 'No Orders'
            WHEN cp.total_spent > 1000 THEN 'High Spender'
            ELSE 'Regular Spender'
        END AS spender_type
    FROM 
        RankedParts rp
    JOIN 
        SupplierStats ss ON rp.p_partkey = ss.s_suppkey
    LEFT JOIN 
        OrderSummary os ON os.line_item_count > 10
    FULL OUTER JOIN 
        CustomerPriorities cp ON cp.order_count = 0
    WHERE 
        rp.price_rank = 1 AND 
        (ss.total_avail_qty IS NOT NULL OR cp.order_count IS NULL)
)
SELECT 
    DISTINCT r.p_name, 
    r.p_brand, 
    r.total_avail_qty, 
    r.avg_acctbal, 
    r.line_item_count, 
    r.total_revenue, 
    r.order_count, 
    r.total_spent, 
    CONCAT('Type: ', r.spender_type, '; Brand: ', r.p_brand) AS report_description
FROM 
    Report r
ORDER BY 
    r.total_revenue DESC, 
    r.total_avail_qty ASC 
LIMIT 20 OFFSET 10;