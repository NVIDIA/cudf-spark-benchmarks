WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'P') 
        AND o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name, 
    p.p_mfgr, 
    COALESCE(total_available, 0) AS total_available, 
    COALESCE(total_spent, 0) AS total_spent,
    CASE 
        WHEN COALESCE(total_available, 0) > COALESCE(total_spent, 0) THEN 'Available'
        ELSE 'Not Available'
    END AS availability_status
FROM 
    part p
LEFT JOIN 
    PartSupplierInfo psi ON p.p_partkey = psi.ps_partkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey 
                                           FROM customer c 
                                           WHERE c.c_acctbal = (
                                               SELECT MAX(c_acctbal) 
                                               FROM customer 
                                               WHERE c_acctbal IS NOT NULL
                                               AND c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
                                           ) 
                                           LIMIT 1) 
WHERE 
    p.p_size > (SELECT AVG(p2.p_size) FROM part p2)
ORDER BY 
    availability_status DESC, 
    total_spent DESC
LIMIT 100;