
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 
                       WHERE s2.s_acctbal IS NOT NULL)
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice + (p.p_retailprice * (0.1 * (SELECT COUNT(*) 
                                                        FROM partsupp ps 
                                                        WHERE ps.ps_partkey = p.p_partkey))) AS adjusted_price
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
ValidOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finished'
            ELSE 'Pending'
        END AS order_status_desc
    FROM
        orders o
    WHERE 
        o.o_totalprice IS NOT NULL
),
FinalAnalysis AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.adjusted_price,
        COUNT(DISTINCT lo.l_orderkey) AS order_count,
        SUM(lo.l_quantity) AS total_quantity,
        COALESCE(SUM(lo.l_discount), 0) AS total_discount
    FROM 
        PartDetails pd
    LEFT JOIN 
        lineitem lo ON pd.p_partkey = lo.l_partkey
    WHERE 
        pd.adjusted_price > 100
    GROUP BY 
        pd.p_partkey, pd.p_name, pd.adjusted_price
)
SELECT 
    fa.p_partkey,
    fa.p_name,
    fa.adjusted_price,
    fa.order_count,
    fa.total_quantity,
    fa.total_discount,
    rs.s_name,
    rs.s_acctbal
FROM 
    FinalAnalysis fa
LEFT JOIN 
    RankedSuppliers rs ON fa.order_count > (SELECT AVG(order_count) 
                                             FROM FinalAnalysis)
WHERE 
    fa.total_discount IS NOT NULL
    AND (rs.rank <= 5 OR rs.rank IS NULL)
ORDER BY 
    fa.adjusted_price DESC, fa.order_count DESC
LIMIT 100;
