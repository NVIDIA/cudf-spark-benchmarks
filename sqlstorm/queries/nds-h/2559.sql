
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    ns.n_name,
    ns.total_sales,
    ns.order_count,
    pd.p_name,
    pd.total_available,
    pd.avg_price,
    COALESCE(rs.s_name, 'N/A') AS top_supplier,
    COALESCE(rs.s_acctbal, 0) AS supplier_balance
FROM 
    NationSales ns
LEFT JOIN 
    RankedSuppliers rs ON ns.n_name = (
        SELECT n.n_name
        FROM nation n
        WHERE n.n_nationkey = (
            SELECT c.c_nationkey
            FROM customer c
            WHERE c.c_custkey = (
                SELECT o.o_custkey
                FROM orders o
                WHERE o.o_totalprice = (
                    SELECT MAX(o1.o_totalprice)
                    FROM orders o1
                    WHERE o1.o_orderstatus = 'O'
                )
                LIMIT 1
            )
        )
    )
JOIN 
    PartDetails pd ON pd.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey
            FROM orders o
            WHERE o.o_orderdate > DATE '1998-10-01' - INTERVAL '30 days'
            AND o.o_totalprice > 1000
        )
    )
WHERE 
    ns.total_sales IS NOT NULL
ORDER BY 
    ns.total_sales DESC, 
    pd.avg_price ASC;
