
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
), HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT AVG(total_price) FROM (
                SELECT 
                    l.l_partkey,
                    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
                FROM 
                    lineitem l
                WHERE 
                    l.l_shipdate >= '1996-01-01' 
                    AND l.l_shipdate < '1996-12-31'
                GROUP BY 
                    l.l_partkey
            ) AS avg_price
        )
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 10
), SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    COALESCE(supp_details.supplier_count, 0) AS total_suppliers,
    cust.total_spent,
    cust.order_count,
    CASE 
        WHEN cust.total_spent IS NULL THEN 'No Orders'
        WHEN cust.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    part p
LEFT JOIN 
    HighValueParts hv ON p.p_partkey = hv.ps_partkey
LEFT JOIN 
    SupplierPartDetails supp_details ON p.p_partkey = supp_details.ps_partkey 
LEFT JOIN 
    RankedSuppliers r ON supp_details.supplier_count > 3 AND r.rank_acctbal = 1
LEFT JOIN 
    CustomerOrders cust ON cust.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'Germany'
        )
    )
WHERE 
    p.p_retailprice > 50.00
ORDER BY 
    p.p_partkey, total_spent DESC;
