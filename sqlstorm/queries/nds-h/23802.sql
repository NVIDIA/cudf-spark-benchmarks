
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate <= '1997-12-31'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
SupplierSaleCounts AS (
    SELECT 
        l.l_suppkey, 
        COUNT(*) AS sale_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
        AND o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        l.l_suppkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
UnexpectedProducts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_size IS NULL OR 
        p.p_comment LIKE '%lightweight%' OR 
        p.p_mfgr NOT IN (SELECT DISTINCT s.s_name FROM supplier s WHERE s.s_nationkey = 0)
),
CombinedData AS (
    SELECT 
        c.c_name,
        o.o_orderdate,
        l.l_discount,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            WHEN l.l_returnflag = 'A' THEN 'Accepted'
            ELSE 'Other'
        END AS return_status,
        ps.ps_supplycost * l.l_quantity AS total_cost,
        p.p_name
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        p.p_partkey IN (SELECT p.p_partkey FROM UnexpectedProducts p)
)
SELECT 
    cd.c_name AS customer_name, 
    cd.o_orderdate,
    SUM(cd.total_cost) AS total_cost,
    COUNT(DISTINCT cd.p_name) AS distinct_product_count,
    SUM(cd.l_discount) AS total_discount,
    RANK() OVER (ORDER BY SUM(cd.total_cost) DESC) AS rank_cost
FROM 
    CombinedData cd 
WHERE 
    cd.return_status = 'Returned'
GROUP BY 
    cd.c_name, cd.o_orderdate
ORDER BY 
    total_cost DESC
LIMIT 10 OFFSET 5;
