
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
),
RegionSupplier AS (
    SELECT 
        r.r_name,
        s.s_name,
        COALESCE(s.s_acctbal, 0) AS acct_balance,
        s.s_suppkey
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
)
SELECT 
    rg.r_name,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
    SUM(ss.total_availqty) AS total_supplied,
    COALESCE(MAX(rg.acct_balance), 0) AS max_balance,
    AVG(hvc.total_spent) AS avg_spent_by_customers
FROM 
    RegionSupplier rg
JOIN 
    SupplierStats ss ON rg.s_suppkey = ss.s_suppkey
JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%John%')
WHERE 
    ss.num_parts > 10
GROUP BY 
    rg.r_name
HAVING 
    COUNT(ss.s_suppkey) > 2
ORDER BY 
    supplier_count DESC, total_supplied DESC
LIMIT 5 OFFSET 1;
