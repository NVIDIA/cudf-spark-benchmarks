
WITH SupplierRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 0
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        sr.s_acctbal
    FROM 
        SupplierRanking sr
    WHERE 
        sr.rank <= 5
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(ps.total_available, 0) AS available_quantity,
    COALESCE(od.net_revenue, 0) AS revenue,
    cs.c_custkey,
    cs.c_name
FROM 
    part p
LEFT JOIN 
    PartSuppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (
        SELECT 
            o.o_orderkey
        FROM 
            orders o
        WHERE 
            o.o_custkey IN (
                SELECT 
                    c.c_custkey 
                FROM 
                    customer c 
                WHERE 
                    c.c_nationkey IN (
                        SELECT 
                            n.n_nationkey 
                        FROM 
                            nation n 
                        WHERE 
                            n.n_name IN (SELECT n.n_name FROM nation n JOIN TopSuppliers ts ON n.n_nationkey = ts.s_suppkey)
                    )
            )
    )
JOIN 
    customer cs ON cs.c_custkey IN (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        JOIN 
            TopSuppliers ts ON c.c_nationkey = ts.s_suppkey
    )
WHERE 
    p.p_retailprice IS NOT NULL
ORDER BY 
    revenue DESC, 
    available_quantity ASC;
