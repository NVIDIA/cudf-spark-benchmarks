WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) as rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartsWithComments AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%quality%'
),
TopLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        l.l_orderkey
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    rc.c_name,
    rc.c_acctbal,
    sd.s_name AS supplier_name,
    sd.nation_name,
    p.p_name,
    p.comment_length,
    tl.total_revenue,
    tl.unique_parts
FROM 
    RankedCustomers rc
JOIN 
    SupplierDetails sd ON rc.c_custkey = sd.s_suppkey
JOIN 
    PartsWithComments p ON rc.c_custkey = p.p_partkey
JOIN 
    TopLineItems tl ON rc.c_custkey = tl.l_orderkey
ORDER BY 
    rc.rank, sd.nation_name, p.comment_length DESC;