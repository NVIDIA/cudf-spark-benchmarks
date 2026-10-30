WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'S') 
        AND li.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS rank_within_date
    FROM 
        SalesCTE
    WHERE 
        sales_rank <= 5
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.o_orderkey,
    tc.o_orderdate,
    tc.total_sales,
    p.p_name,
    ps.ps_supplycost,
    CASE 
        WHEN ps.ps_availqty IS NOT NULL THEN ps.ps_availqty
        ELSE 0
    END AS avail_qty
FROM 
    TopCustomers tc
LEFT JOIN 
    lineitem li ON tc.o_orderkey = li.l_orderkey
LEFT JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey AND ps.ps_suppkey IN (
        SELECT s.s_suppkey 
        FROM supplier s 
        WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    )
LEFT JOIN 
    part p ON li.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 500.00
    AND tc.rank_within_date <= 10
ORDER BY 
    tc.total_sales DESC, tc.o_orderdate DESC;