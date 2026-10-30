WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
), HighValueLines AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        CASE 
            WHEN SUM(l.l_discount) = 0 THEN 'No Discount'
            ELSE 'Discounted'
        END AS discount_status
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), NationSuppliers AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_type
    HAVING 
        SUM(ps.ps_availqty) < 500
)
SELECT 
    n.n_name,
    hs.total_value,
    hs.discount_status,
    so.o_orderkey,
    so.o_orderdate,
    so.o_totalprice
FROM 
    NationSuppliers n
LEFT JOIN 
    HighValueLines hs ON hs.l_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        JOIN 
            RankedOrders ro ON l.l_orderkey = ro.o_orderkey 
        WHERE 
            ro.order_rank <= 10
    )
LEFT JOIN 
    (SELECT 
        o.o_orderkey, o.o_orderdate, o.o_totalprice 
     FROM 
        orders o
     WHERE 
        o.o_orderstatus = 'F') so ON hs.l_orderkey = so.o_orderkey
WHERE 
    n.total_acctbal IS NOT NULL
ORDER BY 
    n.n_name, so.o_totalprice DESC;